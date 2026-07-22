//
//  ViewerPageState.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/21.
//
//
//  ViewerPageState.swift
//  myDiary
//

import SwiftUI
import Observation

/*
 ImageViewer内の1ページに関する表示状態。

 担当する処理：
 - ズーム倍率の保持
 - 画像位置の保持
 - 倍率の制限
 - 画像移動範囲の制限
 - Toolbarからの拡大・縮小・Fit
 - ピンチ終了時の倍率確定
 - ダブルタップ処理
 - パン終了時の位置確定
 */
@Observable
final class ViewerPageState {

    // MARK: - State

    /*
     確定済みのズーム倍率。
     */
    var zoomScale: CGFloat = 1.0

    /*
     確定済みの画像位置。
     */
    var imageOffset: CGSize = .zero

    // MARK: - Constants

    let minimumZoomScale: CGFloat = 1.0
    let maximumZoomScale: CGFloat = 8.0
    let doubleTapZoomScale: CGFloat = 2.0

    /*
     画像の周囲に確保する余白。
     */
    let imageMargin: CGFloat = 40.0

    // MARK: - Toolbar operations

    /*
     ウインドウに収まる倍率へ戻す。
     */
    func fit() {
        zoomScale = minimumZoomScale
        imageOffset = .zero
    }

    /*
     Toolbarから画像を拡大する。
     */
    func zoomIn() {
        zoomScale = limitedZoomScale(
            zoomScale + 0.25
        )
    }

    /*
     Toolbarから画像を縮小する。
     */
    func zoomOut() {
        zoomScale = limitedZoomScale(
            zoomScale - 0.25
        )

        if zoomScale <= minimumZoomScale {
            imageOffset = .zero
        }
    }

    // MARK: - Effective values

    /*
     ピンチ操作中の一時倍率を含めた
     実際の表示倍率を返す。
     */
    func effectiveZoomScale(
        magnification: CGFloat
    ) -> CGFloat {
        limitedZoomScale(
            zoomScale * magnification
        )
    }

    /*
     ドラッグ中の一時移動量を含めた
     実際の表示位置を返す。
     */
    func effectiveOffset(
        dragTranslation: CGSize,
        image: UIImage,
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        magnification: CGFloat
    ) -> CGSize {

        let scale = effectiveZoomScale(
            magnification: magnification
        )

        let requestedOffset = CGSize(
            width:
                imageOffset.width
                + dragTranslation.width,

            height:
                imageOffset.height
                + dragTranslation.height
        )

        return limitedOffset(
            requestedOffset,
            at: scale,
            image: image,
            pageWidth: pageWidth,
            pageHeight: pageHeight
        )
    }

    // MARK: - Magnify

    /*
     ピンチ操作終了時に倍率を確定する。
     */
    func finishMagnification(
        magnification: CGFloat,
        image: UIImage,
        pageWidth: CGFloat,
        pageHeight: CGFloat
    ) {
        let newScale = limitedZoomScale(
            zoomScale * magnification
        )

        zoomScale = newScale

        if newScale <= minimumZoomScale {
            imageOffset = .zero
            return
        }

        imageOffset = limitedOffset(
            imageOffset,
            at: newScale,
            image: image,
            pageWidth: pageWidth,
            pageHeight: pageHeight
        )
    }

    // MARK: - Double tap

    /*
     ダブルタップ位置を中心に拡大する。

     拡大中にダブルタップした場合は
     Fitへ戻す。
     */
    func handleDoubleTap(
        at location: CGPoint,
        image: UIImage,
        pageWidth: CGFloat,
        pageHeight: CGFloat
    ) {
        if zoomScale > 1.1 {
            fit()
            return
        }

        let center = CGPoint(
            x: pageWidth / 2,
            y: pageHeight / 2
        )

        let scaleDifference =
            doubleTapZoomScale
            - minimumZoomScale

        let requestedOffset = CGSize(
            width:
                -(location.x - center.x)
                * scaleDifference,

            height:
                -(location.y - center.y)
                * scaleDifference
        )

        zoomScale = doubleTapZoomScale

        imageOffset = limitedOffset(
            requestedOffset,
            at: doubleTapZoomScale,
            image: image,
            pageWidth: pageWidth,
            pageHeight: pageHeight
        )
    }

    // MARK: - Pan

    /*
     パン終了時に慣性移動後の位置を確定する。
     */
    func finishPan(
        predictedTranslation: CGSize,
        image: UIImage,
        pageWidth: CGFloat,
        pageHeight: CGFloat
    ) {
        guard zoomScale > 1.01 else {
            imageOffset = .zero
            return
        }

        let predictedOffset = CGSize(
            width:
                imageOffset.width
                + predictedTranslation.width,

            height:
                imageOffset.height
                + predictedTranslation.height
        )

        imageOffset = limitedOffset(
            predictedOffset,
            at: zoomScale,
            image: image,
            pageWidth: pageWidth,
            pageHeight: pageHeight
        )
    }

    // MARK: - Reconciliation

    /*
     Toolbarから倍率が変更された場合に、
     現在位置を有効範囲内へ戻す。
     */
    func reconcileOffset(
        image: UIImage,
        pageWidth: CGFloat,
        pageHeight: CGFloat
    ) {
        zoomScale = limitedZoomScale(
            zoomScale
        )

        if zoomScale <= minimumZoomScale {
            imageOffset = .zero
            return
        }

        imageOffset = limitedOffset(
            imageOffset,
            at: zoomScale,
            image: image,
            pageWidth: pageWidth,
            pageHeight: pageHeight
        )
    }

    // MARK: - Limits

    /*
     ズーム倍率を許可範囲内へ制限する。
     */
    private func limitedZoomScale(
        _ value: CGFloat
    ) -> CGFloat {
        min(
            maximumZoomScale,
            max(
                minimumZoomScale,
                value
            )
        )
    }

    /*
     指定倍率で画像を移動できる範囲を計算し、
     オフセットをその範囲内へ制限する。
     */
    private func limitedOffset(
        _ offset: CGSize,
        at scale: CGFloat,
        image: UIImage,
        pageWidth: CGFloat,
        pageHeight: CGFloat
    ) -> CGSize {

        let fittedSize = fittedImageSize(
            image: image,
            pageWidth: pageWidth,
            pageHeight: pageHeight
        )

        let scaledWidth =
            fittedSize.width * scale

        let scaledHeight =
            fittedSize.height * scale

        let maximumX = max(
            0,
            (scaledWidth - pageWidth) / 2
        )

        let maximumY = max(
            0,
            (scaledHeight - pageHeight) / 2
        )

        return CGSize(
            width: min(
                maximumX,
                max(
                    -maximumX,
                    offset.width
                )
            ),

            height: min(
                maximumY,
                max(
                    -maximumY,
                    offset.height
                )
            )
        )
    }

    /*
     1倍表示時にaspect fitされた
     画像の実サイズを計算する。
     */
    private func fittedImageSize(
        image: UIImage,
        pageWidth: CGFloat,
        pageHeight: CGFloat
    ) -> CGSize {

        let availableWidth = max(
            1,
            pageWidth - imageMargin * 2
        )

        let availableHeight = max(
            1,
            pageHeight - imageMargin * 2
        )

        guard image.size.width > 0,
              image.size.height > 0 else {
            return CGSize(
                width: availableWidth,
                height: availableHeight
            )
        }

        let imageAspect =
            image.size.width
            / image.size.height

        let availableAspect =
            availableWidth
            / availableHeight

        if imageAspect > availableAspect {
            return CGSize(
                width: availableWidth,
                height:
                    availableWidth
                    / imageAspect
            )
        }

        return CGSize(
            width:
                availableHeight
                * imageAspect,

            height: availableHeight
        )
    }
}
